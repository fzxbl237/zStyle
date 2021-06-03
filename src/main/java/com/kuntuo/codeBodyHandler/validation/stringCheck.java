package com.kuntuo.codeBodyHandler.validation;
import javax.validation.Constraint;
import javax.validation.Payload;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ ElementType.METHOD, ElementType.FIELD, ElementType.ANNOTATION_TYPE })
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = StringCheckValidator.class)
public @interface stringCheck {
    String[] stringArray()  ;

    String message() default "必须是以下选项中的一个： {stringArray}";

    Class<?>[] groups() default { };

    Class<? extends Payload>[] payload() default { };
}
