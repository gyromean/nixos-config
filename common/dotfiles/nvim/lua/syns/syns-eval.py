from urllib.request import urlopen
import re, json

class Syns:
  def query_synonyms(self, req):
    return self.query(req, 'synonyms', 'Synonyms', -1)

  def query_antonyms(self, req):
    return self.query(req, 'antonyms', 'Antonyms', 1)

  def query(self, req, definition_key, display_name, sort_sign):
    url = f'https://www.thesaurus.com/browse/{req}'
    with urlopen(url) as u:
      if u.status != 200:
        return f'HTTP error, response {u.status}'
      html_text = u.read().decode()

    m = re.search(r'JSON.parse\("(.*)"\)', html_text)

    extracted_json = m.group(1).replace(r'\"', '"').replace(r'\\', '\\')
    loaded_json = json.loads(extracted_json)

    filtered_tuna = list(filter(lambda x: x['type'] == 'fetchTunaResults/fulfilled', loaded_json['loaderData']['0-11']))[0]
    if filtered_tuna['payload']['data'] == None:
      return f"thesaurus.com's page for this word has no data"
    definitions = filtered_tuna['payload']['data']['definitionData']['definitions']

    ret = []

    for d in definitions:
      pos = d['pos'] # verb etc.
      definition = d['definition'] # explanation on the meaning in this context of synonyms
      for syn in d[definition_key]: # jsou tu accessable i ty antonyms, jen je tady nepouzivam, viz dole
        sim = int(syn['similarity'])
        ret.append((syn['term'], sim, pos, definition))

    ret.sort(key=lambda x: (sort_sign * x[1], x[2], x[3], x[0]))
    return (ret, display_name)
