package com.nawin.rest_api.RESTAPIs.service;

import com.nawin.rest_api.RESTAPIs.dto.StudentDto;
import com.nawin.rest_api.RESTAPIs.entity.Students;

import java.util.List;

public interface StudentService {
    List<StudentDto>  getAllStudents();

        StudentDto getStudentsById(Long id) ;
}
