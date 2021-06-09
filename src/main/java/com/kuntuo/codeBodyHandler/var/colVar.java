package com.kuntuo.codeBodyHandler.var;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Data
@Component
@ConfigurationProperties(prefix = "colvar")
public class colVar {
    private String var;

    private String fmt;

    private Map<String,String> pool;

    private String show;

    private Boolean showDenom=true;

    private Boolean inDenomDs=true;
}
