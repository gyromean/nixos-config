from urllib.request import urlopen
from urllib.error import HTTPError
from urllib.parse import quote
import re, json
from pprint import pprint

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
  def request_synonyms(self, input_text):
    return {"prompt_title": f"Synonyms of '{input_text}'"} | self.request_thesaurus(input_text, 'synonyms', -1)

  @lua_error_wrapper
  def request_antonyms(self, input_text):
    return {"prompt_title": f"Antonyms of '{input_text}'"} | self.request_thesaurus(input_text, 'antonyms', 1)

  @staticmethod
  def get_url(url):
    try:
      with urlopen(url) as u:
        if u.status != 200:
          raise Syns.Error(f"HTTP status code {u.status}, aborting")
        return u.read().decode()
    except HTTPError:
      raise Syns.Error(f"HTTPError occured, aborting")


  def request_thesaurus(self, input_text, definition_key, sort_sign):
    if input_text.strip() == '':
      raise Syns.Error('Selection is empty')
    url = f'https://www.thesaurus.com/browse/{quote(input_text)}'
    html_text = Syns.get_url(url)

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

  # --- TRANSLATE ---
  @staticmethod
  def get_html_inner_text(text):
    return re.match(r'<.*>(.+)<.*>', text).group(1)

  @staticmethod
  def is_html_class(text, c=None):
    if c is None:
      return re.search(fr"""class=['"]""", text) is not None
    else:
      return re.search(fr"""class=['"]{c}['"]""", text) is not None

  @staticmethod
  def parse_translation_entry(entry):
    ret = []
    cur_word = {'translation': []}
    meaning = 'default'
    for val in entry:
      val = val.strip()

      if Syns.is_html_class(val):
        if Syns.is_html_class(val, 'c'):
          meaning = Syns.get_html_inner_text(val)[1:-1] # remove parenthesis
        elif Syns.is_html_class(val, 'w'):
          cur_word['translation'].append({'type': 'context', 'val': Syns.get_html_inner_text(val)})
        elif Syns.is_html_class(val, 'no_translation'):
          cur_word['translation'].append({'type': 'normal', 'val': Syns.get_html_inner_text(val)})
      elif len(val) == 0: # space, will add manually later
        pass
      elif ',' in val:
        if len(cur_word['translation']) > 0:
          ret.append(cur_word)
        cur_word = {'translation': []}
      else:
        cur_word['translation'].append({'type': 'normal', 'val': val})

    if len(cur_word['translation']) > 0:
      ret.append(cur_word)

    for r in ret:
      r['meaning'] = meaning

    for r in ret: # concat words of the same type
      words = r['translation']
      words_new = []
      prev_word_type = None
      for word in words:
        if word['type'] == prev_word_type:
          words_new[-1]['val'] += ' ' + word['val']
        else:
          words_new.append(word)
          prev_word_type = word['type']
      r['translation'] = words_new

    return ret

  @staticmethod
  def remove_html_from_example(text):
    text = re.sub(r'''<span class=['"]d['"]>(.*?)</span>''', r'(\1)', text)
    text = re.sub(r'''<span class=['"]w['"]>(.*?)</span>''', r'/\1/', text)
    text = re.sub(r'''<span class=['"].*?['"]>(.*?)</span>''', r'\1', text)
    return text

  @staticmethod
  def parse_examples(translation):
    ret = []
    for ex in translation['coll2']:
      ret.append({
        'src': Syns.remove_html_from_example(ex['coll2s']),
        'dst': Syns.remove_html_from_example(ex['coll2t']),
      })
    for ex in translation['samp2']:
      ret.append({
        'src': Syns.remove_html_from_example(ex['samp2s']),
        'dst': Syns.remove_html_from_example(ex['samp2t']),
      })
    return ret

  @staticmethod
  def translation_to_plain_text(translation):
    return ' '.join(t['val'] for t in translation)

  @staticmethod
  def merge_same_translations(data):
    ret = []
    plain_to_full_translation_dict = {}
    merged = {}
    for rec in data:
      plain_text = Syns.translation_to_plain_text(rec['translation'])
      plain_to_full_translation_dict.setdefault(plain_text, rec['translation'])
      del rec['translation']
      merged.setdefault(plain_text, []).append(rec)
    for key in merged:
      ret.append({
        'translation': plain_to_full_translation_dict[key],
        'definitions': merged[key],
      })

    return ret

  @staticmethod
  @lua_error_wrapper
  def request_translation(input_text):
    return {"prompt_title": f"Translation of '{input_text}'", "data": Syns.request_translation_(input_text)}

  @staticmethod
  def request_translation_(input_text):
    if input_text.strip() == '':
      raise Syns.Error('Selection is empty')
    url = f'https://slovnik.seznam.cz/preklad/cesky_anglicky/{quote(input_text)}'
    html_text = Syns.get_url(url)

    m = re.search(r'type="application/json">(.+)</script>', html_text)

    loaded_json = json.loads(m.group(1))
    translations = loaded_json['props']['pageProps']['translations'][0]['sens']
    word = loaded_json['props']['pageProps']['head']['entr']

    ret = []

    for translation in translations:
      print(f'{translation = }')
      print(f'{Syns.parse_examples(translation) = }')
      examples = Syns.parse_examples(translation)
      for t in translation['trans']:

        rs = Syns.parse_translation_entry(t)
        print(f'{t = }')
        print(f'{rs = }')
        for r in rs:
          r['examples'] = examples
        ret.extend(rs)

    pprint(ret)
    ret = Syns.merge_same_translations(ret)
    print('--------')
    pprint(ret)
    return ret


  # TODO: tohle pak movnout do ty funkce request_translate
  # input_text = 'autícko'
  # input_text = 'býť' # TODO: priklad slova ktery to nezna, takze nejak to osefit
  # json.dump(
  # TODO: prozkoumat `autíčko` vs `letadlo`

  # TODO: viď je tam ten notranslate

  # pprint(xd)

if __name__ == '__main__':
  Syns.request_translation('být')
