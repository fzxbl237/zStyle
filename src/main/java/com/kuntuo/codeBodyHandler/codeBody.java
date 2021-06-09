package com.kuntuo.codeBodyHandler;

import com.kuntuo.codeBodyHandler.format.fmtMapper;
import com.kuntuo.codeBodyHandler.inds.indsDetail;
import com.kuntuo.codeBodyHandler.validation.stringCheck;
import com.kuntuo.codeBodyHandler.var.colVar;
import com.kuntuo.codeBodyHandler.var.linVar;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import java.util.List;

@Data
@Component
@ConfigurationProperties(prefix = "body")
public class codeBody {
    @NotNull
    @stringCheck(stringArray={"occds"})
    private String module;

    private indsDetail inds;

    private indsDetail denomDs;

    @Pattern(regexp = "\\w+",message = "您输出的文件名似乎不是sas文件")
    private String fileName;

    private List<colVar> colVars;

    private List<linVar> linVars;

    private List<fmtMapper> fmtMaps;

    private String[] statList;
}
