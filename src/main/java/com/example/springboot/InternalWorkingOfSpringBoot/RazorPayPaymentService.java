package com.example.springboot.InternalWorkingOfSpringBoot;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;
// @Service
// @RestContoller
// @Repository
// @Controller

@Component
@ConditionalOnProperty(name="payment.provider", havingValue="razorpay")
public class RazorPayPaymentService implements PaymentService   {

    @Override
    public String pay() {
        String paymentStatus = "done";
        System.out.println(paymentStatus+ " from razorpay");
        return paymentStatus;
    }
}
