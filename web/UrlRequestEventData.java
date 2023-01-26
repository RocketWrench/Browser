
package web;

import org.cef.network.CefURLRequest;

public class UrlRequestEventData {
    
    public UrlRequestType Type;
    public CefURLRequest Request;
    public int Current;
    public int Total;
    public byte[] Data;
    /*public Boolean IsProxy;
    public String Host;
    public int Port;*/
    
    public UrlRequestEventData( CefURLRequest request ){
        this.Type = UrlRequestType.REQUEST_COMPLETE;
        this.Request = request;
    } 

    public UrlRequestEventData( UrlRequestType type, CefURLRequest request, int current, int total ){
        this.Type = type;
        this.Request = request;
        this.Current = current;
        this.Total = total;
    }
    
    public UrlRequestEventData( CefURLRequest request, byte[] data, int length ){
        this.Type = UrlRequestType.DOWNLOAD_DATA;
        this.Request = request;
        this.Data = data;
        this.Total = length;
    }     
}
