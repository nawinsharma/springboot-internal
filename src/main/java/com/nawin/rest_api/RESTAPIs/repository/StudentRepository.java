package com.nawin.rest_api.RESTAPIs.repository;

import com.nawin.rest_api.RESTAPIs.entity.Students;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface StudentRepository extends JpaRepository<Students, Long > {
}
