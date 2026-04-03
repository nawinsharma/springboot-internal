package com.example.springboot.InternalWorkingOfSpringBoot;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.AutoConfigureOrder;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class InternalWorkingOfSpringBootApplication implements CommandLineRunner {

	public static void main(String[] args) {
		SpringApplication.run(InternalWorkingOfSpringBootApplication.class, args);
	}
	// field injection
 //	@Autowired
	private  PaymentService paymentService;
// constructor dependency injection
	public  InternalWorkingOfSpringBootApplication(PaymentService paymentService) {
		this.paymentService = paymentService;
	}
	@Override
	public void run(String... args) throws Exception{
		String paymentStatus = paymentService.pay();
		System.out.println("payment done: "+paymentStatus);
	}
}
