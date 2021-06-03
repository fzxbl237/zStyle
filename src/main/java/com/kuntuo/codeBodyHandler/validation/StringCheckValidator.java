package com.kuntuo.codeBodyHandler.validation;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;

public class StringCheckValidator implements ConstraintValidator<stringCheck, String> {

    private String[] str;
    @Override
    public void initialize(stringCheck stringCheck) {
        str = stringCheck.stringArray();
    }

    @Override
    public boolean isValid(String value, ConstraintValidatorContext constraintValidatorContext) {
        for (String s : str) {
            if(value!=null){
                if(s.toUpperCase()==value.toUpperCase())
                    return true;
            }
        }
        return false;
    }
}
