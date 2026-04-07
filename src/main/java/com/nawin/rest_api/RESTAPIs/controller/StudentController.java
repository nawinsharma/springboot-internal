package com.nawin.rest_api.RESTAPIs.controller;

import com.nawin.rest_api.RESTAPIs.dto.StudentDto;
import com.nawin.rest_api.RESTAPIs.entity.Students;
import com.nawin.rest_api.RESTAPIs.repository.StudentRepository;
import com.nawin.rest_api.RESTAPIs.service.StudentService;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@AllArgsConstructor
public class StudentController {
    private final StudentService studentService;

    @GetMapping("/students")
    public List<StudentDto> getAllStudent() {
        return  studentService.getAllStudents();
    }

    @GetMapping("/student/{id}")
    public String getStudentById(@PathVariable Long id) {
        return  new StudentService.getStudentsById(id);
    }

}
