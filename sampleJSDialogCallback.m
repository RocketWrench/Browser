function sampleJSDialogCallback( type, URL, message, prompt, callback )

    switch type
        case 'JSDIALOGTYPE_CONFIRM'
    
        case 'JSDIALOGTYPE_PROMPT'
            prompt = {prompt};
            title = URL;
            dflt = {message};
            answer = inputdlg(prompt,title,[1,120],dflt);
            if isempty(answer)
                callback.Continue(false,prompt);
            else
                callback.Continue(true,answer{1});
            end                            
    end
end