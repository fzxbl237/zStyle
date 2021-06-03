import com.alibaba.fastjson.JSON;
import com.kuntuo.codeBodyHandler.codeBody;
import com.kuntuo.codeBodyHandler.tempCodeBody.occds;
import com.kuntuo.utils.FileUtil;
import com.kuntuo.utils.MapUtil;
import freemarker.template.Configuration;
import freemarker.template.Template;
import org.junit.Test;

import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;
import java.io.File;
import java.io.FileWriter;
import java.io.Writer;
import java.lang.reflect.Field;
import java.util.*;
import java.util.regex.Pattern;

public class test1 {

    @Test
    public void test(){
        occds occds = new occds();
        occds.setUniqueId("111");
//        occds.setModule("occds1");
        //对传入的参数进行基本的格式验证
        Validator validator = Validation.buildDefaultValidatorFactory().getValidator();
        Set<ConstraintViolation<occds>> set = validator.validate(occds);
        for (ConstraintViolation<occds> progBodyConstraintViolation : set) {
            Object enumClass = progBodyConstraintViolation.getConstraintDescriptor().getAttributes().get("enumClass");
            System.out.println("参数"+progBodyConstraintViolation.getPropertyPath()+progBodyConstraintViolation.getMessage());
        }

    }

    @Test
    public void test02() throws ClassNotFoundException, IllegalAccessException {
        String filePath="src/main/resources/test.json";
        String jsonContent = FileUtil.ReadFile(filePath);
        codeBody codeBody= JSON.parseObject(jsonContent, codeBody.class);
        String module = codeBody.getModule();


        Map<String, Object> map = MapUtil.getMap(module, jsonContent);
        // step1 创建freeMarker配置实例
        Configuration configuration = new Configuration();
        Writer out = null;
        try {
            // step2 获取模版路径
            configuration.setDirectoryForTemplateLoading(new File("src/main/resources/temp"));
            configuration.setClassicCompatible(true);
            // step3 创建数据模型
            Map<String, Object> dataMap = new HashMap<String, Object>();

            dataMap.putAll(map);

            // step4 加载模版文件
            Template template = configuration.getTemplate("occds.ftl");
            configuration.setDefaultEncoding("UTF-8");
            template.setEncoding("UTF-8");
            // step5 生成数据
            out = new FileWriter("src/main/resources/temp/out.sas");
            // step6 输出文件
            template.process(dataMap, out);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (null != out) {
                    out.flush();
                }
            } catch (Exception e2) {
                e2.printStackTrace();
            }
        }


    }
}
