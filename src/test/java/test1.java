import com.alibaba.fastjson.JSON;
import com.kuntuo.codeBodyHandler.codeBody;
import com.kuntuo.codeBodyHandler.tempCodeBody.occds;

import com.kuntuo.headerHandler.excelImport.importExcel;
import com.kuntuo.headerHandler.pojo.headerInfo;
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
        String filePath="src/main/resources/T14.1.1.json";
        String jsonContent = FileUtil.ReadFile(filePath);
        codeBody codeBody= JSON.parseObject(jsonContent, codeBody.class);
        //拿到module中的map集合
        String module = codeBody.getModule();
        occds body =  JSON.parseObject(jsonContent, occds.class);
        Map<String, Object> map = MapUtil.getMap(module, jsonContent);
        System.out.println(map);

        String fileName = "src/main/resources/excel/ZZA13331_Header_init.xlsx";
        headerInfo cursdtm=null;
        //拿到Header详细信息;
        List<headerInfo> sdtms = new importExcel<headerInfo>().parseExcel(fileName, headerInfo.class, "SDTM");
        //拿到项目的公共信息
        List<Map<String,String>> projInfos = new importExcel<Map<String,String>>().parseExcel(fileName,null,"projInfo");

        //将项目的公共信息放在Map集合中
        Map<String,String> conMap=new HashMap<String, String>();
        for (Map<String, String> projInfo : projInfos) {
            conMap.put(projInfo.get(0),projInfo.get(1));
        }

        for (headerInfo sdtm : sdtms) {
            if (sdtm.getProgNam().equals("d_0dm")){
                cursdtm=sdtm;
            }
        }
        //注入项目程序头详细信息
        Class aClass = (Class) cursdtm.getClass();
        Map<String,Object> headerMap=new HashMap<>();
        Field[] field = aClass.getDeclaredFields();
        for (Field f : field) {
            f.setAccessible(true);
            String attrNam=f.getName();
            Object o=f.get(cursdtm);
            headerMap.put(attrNam,o);
        }

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
            dataMap.putAll(headerMap);
            dataMap.putAll(conMap);

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
