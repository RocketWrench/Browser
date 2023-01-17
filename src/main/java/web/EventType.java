
package web;

import java.util.HashMap;
import java.util.Map;

    public enum EventType{
        LOAD_ERROR(-1),
        ADDRESS_CHANGE(1),
        TITLE_CHANGE(2),
        STATUS_MESSAGE(3),
        CONSOLE_MESSAGE(4),
        TOOLTIP(5),
        CURSOR_CHANGE(6),
        LOADING_STATE_CHANGE(7),
        LOAD_START(8),
        LOAD_END(9),
        BEFORE_POPUP(10),
        AFTER_CREATED(11),
        AFTER_PARENT_CHANGED(12),
        ON_DIALOG(13); 
        
        private static final Map<Integer, EventType> TYPES = new HashMap<>();
        private final int type;
        
        static{
            for (EventType et : values()){
                if (!TYPES.containsKey(Integer.valueOf(et.type)));
                    TYPES.put(Integer.valueOf(et.type),et);
            }
        }
        EventType(int type){
            this.type = type;
        }
        
        public int getCode(){
            return this.type;
        }
        
        public static EventType findByCode( int type ) {
            return TYPES.get(type);
        }
    }
