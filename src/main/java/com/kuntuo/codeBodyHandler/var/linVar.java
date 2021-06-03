package com.kuntuo.codeBodyHandler.var;

import lombok.Data;

import java.util.List;

@Data
public class linVar {
    private String var;

    private String decode;

    private String fmt;

    private List<String> stat;

    private String label;

    private Boolean totalRow;

    private String totalRowPosition;

    private String uncodeLabel;

    private String uncodePrior;

    private String indent;
}
