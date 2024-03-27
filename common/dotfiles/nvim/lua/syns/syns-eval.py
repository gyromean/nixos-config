from urllib.request import urlopen
from urllib.error import HTTPError
from urllib.parse import quote
import re, json

class Syns:
  class Error(Exception):
    pass

  @staticmethod
  def lua_error_wrapper(func):
    def ret(*args, **kwargs):
      try:
        return {"ok": True, "content": func(*args, **kwargs)}
      except Syns.Error as e:
        return {"ok": False, "content": e.args[0]}
    return ret

  @lua_error_wrapper
  def query_synonyms(self, input_text):
    return {"prompt_title": f"Synonyms of '{input_text}'"} | self.query(input_text, 'synonyms', -1)

  @lua_error_wrapper
  def query_antonyms(self, input_text):
    return {"prompt_title": f"Antonyms of '{input_text}'"} | self.query(input_text, 'antonyms', 1)

  def query(self, input_text, definition_key, sort_sign):
    input_text_quoted = quote(input_text)
    url = f'https://www.thesaurus.com/browse/{input_text_quoted}'
    try:
      with urlopen(url) as u:
        if u.status != 200:
          raise Syns.Error(f"HTTP error for word '{input_text}', response {u.status}")
        html_text = u.read().decode()
    except HTTPError:
      raise Syns.Error(f"Requested word '{input_text}' not found")

    m = re.search(r'JSON.parse\("(.*)"\)', html_text)

    extracted_json = m.group(1).replace(r'\"', '"').replace(r'\\', '\\')
    loaded_json = json.loads(extracted_json)

    filtered_tuna = list(filter(lambda x: x['type'] == 'fetchTunaResults/fulfilled', loaded_json['loaderData']['0-11']))[0]
    if filtered_tuna['payload']['data'] == None:
      raise Syns.Error(f"thesaurus.com's page for word '{input_text}' has no data")
    definitions = filtered_tuna['payload']['data']['definitionData']['definitions']

    ret = []

    for d in definitions:
      pos = d['pos'] # verb etc.
      definition = d['definition'] # explanation on the meaning in this context of synonyms
      for syn in d[definition_key]:
        sim = int(syn['similarity'])
        ret.append((syn['term'], sim, pos, definition))

    if len(ret) == 0:
      raise Syns.Error(f"thesaurus.com's page for '{input_text}' has no data")

    ret.sort(key=lambda x: (sort_sign * x[1], x[2], x[3], x[0]))
    return {
      "data": ret,
    }
