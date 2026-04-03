package com.example.springboot.InternalWorkingOfSpringBoot;


import org.springframework.stereotype.Service;

public interface PaymentService {

    public default String pay(){
        System.out.println("pay");
        return pay().toString();
    }
}