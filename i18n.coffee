
spawn = require('child_process').spawn

I18n =
  detectLang: (text) ->
    cjkCount =
      text.split('').reduce (prev, curr) ->
        if 0x4E00 <= curr.codePointAt(0) <= 0x9FFF # Unicode CJK block
          prev + 1
        else
          prev
      , 0
    if cjkCount > 0
      'zh'
    else
      'en'

  translate: (lang, textData, callback) ->
    if typeof textData == 'object' and textData[lang]?
      callback textData[lang]
      return

    if typeof textData != 'string'
      textData = textData.en

    translator = spawn 'trans', ['-b', '-no-ansi', '-t', lang, textData]
    translator.stdout.on 'data', (chunk) ->
      text = chunk.toString 'utf8'
      callback text

module.exports = I18n
