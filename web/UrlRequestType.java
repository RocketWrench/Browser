package web;

import java.util.HashMap;
import java.util.Map;


    public enum UrlRequestType{
        REQUEST_COMPLETE(1),
        UPLOAD_PROGRESS(2),
        DOWNLOAD_PROGRESS(3),
        DOWNLOAD_DATA(4),
        GET_CREDENTIAALS(5); 
        
        private static final Map<Integer, UrlRequestType> TYPES = new HashMap<>();
        private final int type;
        
        static{
            for (UrlRequestType et : values()){
                if (!TYPES.containsKey(Integer.valueOf(et.type)));
                    TYPES.put(Integer.valueOf(et.type),et);
            }
        }
        UrlRequestType(int type){
            this.type = type;
        }
        
        public int getCode(){
            return this.type;
        }
        
        public static UrlRequestType findByCode( int type ) {
            return TYPES.get(type);
        }
    }
