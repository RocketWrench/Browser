package web;

import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.CefSettings;
import org.cef.network.CefRequest;
import org.cef.handler.CefLoadHandler;
import org.cef.callback.CefJSDialogCallback;

public class BrowserEventData {

    public EventType Type;
    public CefBrowser Browser;
    public int BrowserId;
    /*public CefFrame Frame;*/
    public boolean IsMainFrame;
    public String FrameName;
    public String URL;
    public String Title;
    public String Tooltip;
    public String StatusMessage;
    public String ConsoleMessage;
    public CefSettings.LogSeverity LogSeverity;
    public String ConsoleMessageSource;
    public int ConsoleMessageLine;
    public int CursorIdentifier;
    public CefRequest.TransitionType TransitionType;
    public boolean IsLoading;
    public boolean CanGoBack;
    public boolean CanGoForward;
    public int HTTPStatusCode;
    public CefLoadHandler.ErrorCode ErrorCode;
    public String ErrorText;
    public String SourceText;
    public String DialogType;
    public CefJSDialogCallback DialogCallback; 
    
    public BrowserEventData(CefBrowser browser,
                               String origin_url,
                               String dialog_type,
                               String message_text,
                               String default_prompt_text,
                               CefJSDialogCallback callback){
        
        this.Type = EventType.ON_DIALOG;
        this.Browser = browser;
        this.URL = origin_url;
        this.DialogType = dialog_type;
        this.StatusMessage = message_text;
        this.ConsoleMessage = default_prompt_text;
        this.DialogCallback = callback;
    }
    
    public BrowserEventData( String source  ){
        this.Type = EventType.SOURCE_DOWNLOAD;
        this.SourceText = source;
    }
    
    public BrowserEventData( String suggestedName, String url ){
        this.Type = EventType.IMAGE_DOWNLOAD;
        this.Title = suggestedName;
        this.URL = url;
    } 
    
      public BrowserEventData(CefBrowser browser ){
        this.Type = EventType.AFTER_PARENT_CHANGED;
        this.Browser = browser;
    } 
    
    public BrowserEventData(CefBrowser browser, CefFrame frame, CefLoadHandler.ErrorCode errorCode,String errorText,String failedUrl ){
        this.Type = EventType.LOAD_ERROR;
        this.Browser = browser; 
        /*this.Frame = frame;*/
        this.IsMainFrame = frame.isMain();
        this.ErrorCode = errorCode;
        this.ErrorText = errorText;
        this.URL = failedUrl;
    } 
    
    public BrowserEventData(CefBrowser browser, CefFrame frame, int httpStatusCode){
        this.Type = EventType.LOAD_END;
        this.Browser = browser; 
        /*this.Frame = frame;*/
        this.IsMainFrame = frame.isMain();
        this.FrameName = frame.getName();
        this.HTTPStatusCode = httpStatusCode;
    }  
    
    public BrowserEventData(CefBrowser browser, CefFrame frame, CefRequest.TransitionType transitionType){
        this.Type = EventType.LOAD_START;
        this.Browser = browser; 
        /*this.Frame = frame;*/
        this.IsMainFrame = frame.isMain();
        this.FrameName = frame.getName();
        this.TransitionType = transitionType;
    }    
    
    public BrowserEventData(CefBrowser browser, boolean isloading, boolean cangoback, boolean cangoforward){
        this.Type = EventType.LOADING_STATE_CHANGE;
        this.Browser = browser; 
        this.IsLoading = isloading;
        this.CanGoBack = cangoback;
        this.CanGoForward = cangoforward;
    }    
    
    public BrowserEventData(CefBrowser browser, int id){
        this.Type = EventType.AFTER_CREATED;
        this.Browser = browser; 
        this.BrowserId = id;
    }
    
     public BrowserEventData(CefBrowser browser, CefFrame frame, String url){
        this.Type = EventType.ADDRESS_CHANGE;
        this.Browser = browser;
        this.IsMainFrame = frame.isMain();
        this.URL = url;
    }
     
    public BrowserEventData(CefBrowser browser, CefFrame frame, String url, String framename){
        this.Type = EventType.BEFORE_POPUP;
        this.Browser = browser;
        this.IsMainFrame = frame.isMain();
        this.URL = url;
        this.FrameName = framename;
    } 
    
    public BrowserEventData(CefBrowser browser, EventType type, String str){
        this.Type = type;
        this.Browser = browser;
        switch (type){
            case TITLE_CHANGE:
                this.Title = str;
                break;
            case STATUS_MESSAGE:
                this.StatusMessage = str;
                break;
            case TOOLTIP:
                this.Tooltip = str;
        }
    }
    
    public BrowserEventData(CefBrowser browser, CefSettings.LogSeverity severity, String message, String source, int line){
        this.Type = EventType.CONSOLE_MESSAGE;
        this.Browser = browser;
        this.LogSeverity = severity;
        this.ConsoleMessage = message;
        this.ConsoleMessageSource = source;
        this.ConsoleMessageLine = line;
    }    
}
