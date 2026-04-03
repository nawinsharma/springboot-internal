package com.example.springboot.InternalWorkingOfSpringBoot;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name="payment.provider", havingValue="stripe")
public class StripePaymentService implements  PaymentService {

    @Override
    public String pay() {
        String paymentStatus = "done";
        System.out.println(paymentStatus+ " from stripe");
        return paymentStatus;
    }
}
