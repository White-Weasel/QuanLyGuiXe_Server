def replace_last(txt: str, find: str, repl: str = ''):
    k = txt.rfind(find)
    return txt[:k] + repl + txt[k + len(find):]
