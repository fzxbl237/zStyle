package com.kuntuo.codeBodyHandler.format;

import lombok.Data;

import java.util.Map;

@Data
public class fmtMapper {
    private String fmtType;

    private Map<String,String> fmtMap;

    private String fmtName;
}
