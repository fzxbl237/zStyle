package com.kuntuo.utils;

import com.alibaba.fastjson.JSON;
import com.kuntuo.codeBodyHandler.tempCodeBody.occds;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;

public class MapUtil {
    public static Map<String,Object> getMap(String module,String jsonContent) throws ClassNotFoundException, IllegalAccessException {
        Map<String,Object> map=new HashMap<>();
        if(module.toLowerCase().equals("occds")){
            occds body =  JSON.parseObject(jsonContent, occds.class);
            Class aClass = (Class) body.getClass();
            //遍历子类中的所有属性
            Field[] field = aClass.getDeclaredFields();
            for (Field f : field) {
                f.setAccessible(true);
                String attrNam=f.getName();
                Object o=f.get(body);
                map.put(attrNam,o);
            }
            //遍历父类中的所有属性
            if(aClass.getGenericSuperclass()!=null){
                Class superclass = aClass.getSuperclass();
                Field[] declaredFields = superclass.getDeclaredFields();
                for (Field declaredField : declaredFields) {
                    declaredField.setAccessible(true);
                    String attrNam=declaredField.getName();
                    Object o=declaredField.get(body);
                    map.put(attrNam,o);
                }
            }


        }
        return map;

    }
}
