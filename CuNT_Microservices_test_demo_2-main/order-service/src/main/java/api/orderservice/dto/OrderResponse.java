package api.orderservice.dto;


import lombok.*;

import java.math.BigDecimal;

@NoArgsConstructor
@AllArgsConstructor
@Builder
@Getter
@Setter
public class OrderResponse {
    private Long id;
    private Long productId;
    private Integer quantity;
    private String status;
    private BigDecimal totalPrice;
    private String message;
}
