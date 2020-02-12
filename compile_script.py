from browser import document,window
from io import StringIO
from traceback import print_exc
from javascript import JSON

editor_key = 'editor_content'

def compile(event):
    editor_content = window[editor_key]
    globals_no_main = dict(globals())
    globals_no_main['__name__'] = 'script'

    print('*'*79)
    #print('* compiling this currently loaded script:' + editor_content)
    print('* compiling currently loaded script:')

    try:
        exec(editor_content, globals_no_main, locals())
        design = main()
        #json_str = design.to_json(suppress_indent=False)
        json_dict = design.to_json_serializable(suppress_indent=False)
        print(f'which resulted in this json_dict I am about to stringify:\n{json_dict}')
        #json_str = JSON.stringify(json_dict)
        #print(f'which resulted in this json_str I am about to load:\n{json_str}')
        #window.set_new_design_from_json(json_str)
        window.set_new_design_from_json_map(json_dict)
    except Exception:
        f = StringIO()
        print_exc(file=f)
        stacktrace = f.getvalue()
        window.set_error_message_from_python_script(f"error in Python script:\n\n{stacktrace}")

document['compile'].bind('click', compile)