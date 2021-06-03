package com.kuntuo.codeBodyHandler.var;

import lombok.Data;

import java.util.Map;

@Data
public class colVar {
    private String var;

    private String fmt;

    private Map<String,String> pool;

    private String show;

    private String showDenom;

    private String inDenomDs;
}
