package com.kuntuo.codeBodyHandler.var;

import lombok.Data;

@Data
public class acrossVar {
    private String var;

    private String decode;

    private String fmt;

    private boolean missingDisplay;

    private String missingDisplayLabel;

    private float missingDisplayPrior;

    private String limitOption;

    private Boolean eventLimit;

    private int relatIndent;
}
