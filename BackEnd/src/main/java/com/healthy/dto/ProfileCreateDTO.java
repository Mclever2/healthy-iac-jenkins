package com.healthy.dto;

import com.healthy.model.enums.Gender;
import lombok.Data;


@Data
public class ProfileCreateDTO {
    private String userName;
    private Float height;
    private Float weight;
    private Integer age;
    private Gender gender;
    private String healthConditions;
}
