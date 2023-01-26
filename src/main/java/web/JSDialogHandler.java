
package web;

import org.cef.handler.CefJSDialogHandlerAdapter;
import org.cef.browser.CefBrowser;
import org.cef.callback.CefJSDialogCallback;
import org.cef.misc.BoolRef;

import com.mathworks.jmi.Callback;
        
public class JSDialogHandler extends CefJSDialogHandlerAdapter{
    
    private final Callback callback_ = new Callback();
    
    @Override
    public boolean onJSDialog( CefBrowser browser,
                               String origin_url,
                               JSDialogType dialog_type,
                               String message_text,
                               String default_prompt_text,
                               CefJSDialogCallback callback,
                               BoolRef suppress_message){
        
        suppress_message.set(false); 
        
        if (JSDialogType.JSDIALOGTYPE_ALERT != dialog_type){            

            this.callback_.postCallback(
                new BrowserEventData(browser,origin_url,dialog_type.toString(),
                        message_text,default_prompt_text,callback)); 
            return true;            
        }else{
            return false;
        }                     
    }
    
    @Override
    public boolean onBeforeUnloadDialog( CefBrowser browser,
                                         String message_text,
                                         boolean is_reload,
                                         CefJSDialogCallback callback){      
        return false;
    }
    
    @Override
    public void onResetDialogState( CefBrowser browser ){
        
    };
    
    @Override
    public void onDialogClosed( CefBrowser browser ){
        
    }
    
    public Callback getCallback(){
        
        return this.callback_;
    }
    
}