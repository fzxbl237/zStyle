package com.kuntuo.codeBodyHandler.format;

import lombok.Data;

import java.util.LinkedHashMap;

@Data
public class fmtMapper {
    private String fmtType;

    private LinkedHashMap<String,String> fmtMap;

    private String fmtName;
}
