package com.kuntuo.codeBodyHandler.tempCodeBody;

import com.kuntuo.codeBodyHandler.anyEvent.anyEvent;
import com.kuntuo.codeBodyHandler.codeBody;
import com.kuntuo.codeBodyHandler.var.acrossVar;
import lombok.Data;

import javax.validation.constraints.Pattern;

@Data
public class occds extends codeBody {

    private acrossVar acrossVar;

    @Pattern(regexp = "[a-zA-Z_]\\w*",message = "不符合sas变量的命名规则")
    private String uniqueId;

    private anyEvent anyEvent;

    
}
