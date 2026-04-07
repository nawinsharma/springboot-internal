package com.nawin.rest_api.RESTAPIs.service.impl;

import com.nawin.rest_api.RESTAPIs.dto.StudentDto;
import com.nawin.rest_api.RESTAPIs.entity.Students;
import com.nawin.rest_api.RESTAPIs.repository.StudentRepository;
import com.nawin.rest_api.RESTAPIs.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StudentServiceImpl implements StudentService {
    private final StudentRepository studentRepository;
    @Override
    public List<StudentDto> getAllStudents() {
        List<Students> students = studentRepository.findAll();
        return students.stream()
                .map(student -> new StudentDto(
                        student.getId(),
                        student.getName(),
                        student.getEmail()))
                .toList();
    }

    @Override
    public StudentDto getStudentsById(Long id) {
        Students student =  studentRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Students not found with id"+id));
    }
}
