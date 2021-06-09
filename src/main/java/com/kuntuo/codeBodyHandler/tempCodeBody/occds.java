package com.kuntuo.codeBodyHandler.tempCodeBody;

import com.kuntuo.codeBodyHandler.anyEvent.anyEvent;
import com.kuntuo.codeBodyHandler.codeBody;
import com.kuntuo.codeBodyHandler.var.acrossVar;
import lombok.Data;
import lombok.Getter;
import lombok.ToString;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import javax.validation.constraints.Pattern;

/**
 * @program: sasCodeGenerator
 * @description: occds模块，主要用于产生SOC&PT类型的表格
 * @author: zhi.xu
 * @create: 2021-06-04 10:24
 **/

@Data
@ToString(callSuper =true)
@Getter()
@Component
@ConfigurationProperties(prefix = "occds")
public class occds extends codeBody {

    private acrossVar acrossVar;

    @Pattern(regexp = "[a-zA-Z_]\\w*",message = "不符合sas变量的命名规则")
    private String uniqueId;

    private anyEvent anyEvent;

    private int[] sortList;

}
