package api.orderservice.service;

import api.orderservice.client.InventoryClient;
import api.orderservice.dto.OrderRequest;
import api.orderservice.dto.OrderResponse;
import api.orderservice.dto.ProductDto;
import api.orderservice.entity.Order;
import api.orderservice.repository.OrderRepository;
import feign.FeignException;
import lombok.AllArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;

@Service
@AllArgsConstructor
public class OrderService {
    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository orderRepository;
    private final InventoryClient inventoryClient;

    @Transactional
    public OrderResponse createOrder(OrderRequest request) {
        if (request.getProductId() == null || request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "ProductId and valid positive quantity are " +
                    "required");
        }

        ProductDto product;
        try {
            log.info("Calling Inventory Service via OpenFeign for productId: {}", request.getProductId());
            product = inventoryClient.getProductById(request.getProductId());
        } catch (FeignException.NotFound e) {
            log.warn("Product not found in Inventory Service: {}", request.getProductId());
            Order cancelledOrder = Order.builder()
                    .productId(request.getProductId())
                    .quantity(request.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .build();
            Order saved = orderRepository.save(cancelledOrder);
            return OrderResponse.builder()
                    .id(saved.getId())
                    .productId(saved.getProductId())
                    .quantity(saved.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .message("Product not found with id: " + request.getProductId())
                    .build();
        } catch (Exception e) {
            log.error("Failed to communicate with Inventory Service: {}", e.getMessage());
            Order cancelledOrder = Order.builder()
                    .productId(request.getProductId())
                    .quantity(request.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .build();
            Order saved = orderRepository.save(cancelledOrder);
            return OrderResponse.builder()
                    .id(saved.getId())
                    .productId(saved.getProductId())
                    .quantity(saved.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .message("Unable to verify inventory: " + e.getMessage())
                    .build();
        }

        // Kiem tra so luong ton kho
        if (product.getQuantity() == null || product.getQuantity() < request.getQuantity()) {
            log.warn("Insufficient stock for productId: {}. Available: {}, Requested: {}",
                    request.getProductId(), product.getQuantity(), request.getQuantity());

            Order cancelledOrder = Order.builder()
                    .productId(request.getProductId())
                    .quantity(request.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .build();
            Order saved = orderRepository.save(cancelledOrder);

            return OrderResponse.builder()
                    .id(saved.getId())
                    .productId(saved.getProductId())
                    .quantity(saved.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .message(String.format("Insufficient stock. Available: %d, Requested: %d",
                            product.getQuantity() != null ? product.getQuantity() : 0, request.getQuantity()))
                    .build();
        }

        // Tinh tong tien = don gia * so luong
        BigDecimal unitPrice = product.getPrice() != null ? product.getPrice() : BigDecimal.ZERO;
        BigDecimal totalPrice = unitPrice.multiply(BigDecimal.valueOf(request.getQuantity()));

        // Tru kho thong qua Inventory Service
        try {
            inventoryClient.deductStock(request.getProductId(), request.getQuantity());
            log.info("Deducted {} items for productId: {} from inventory", request.getQuantity(), request.getProductId());
        } catch (Exception e) {
            log.error("Failed to deduct stock from Inventory Service: {}", e.getMessage());
            Order cancelledOrder = Order.builder()
                    .productId(request.getProductId())
                    .quantity(request.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .build();
            Order saved = orderRepository.save(cancelledOrder);
            return OrderResponse.builder()
                    .id(saved.getId())
                    .productId(saved.getProductId())
                    .quantity(saved.getQuantity())
                    .status("CANCELLED")
                    .totalPrice(BigDecimal.ZERO)
                    .message("Stock deduction failed: " + e.getMessage())
                    .build();
        }

        Order order = Order.builder()
                .productId(request.getProductId())
                .quantity(request.getQuantity())
                .status("COMPLETED")
                .totalPrice(totalPrice)
                .build();

        Order saved = orderRepository.save(order);
        log.info("Order created successfully with id: {}, total_price: {}", saved.getId(), saved.getTotalPrice());

        return OrderResponse.builder()
                .id(saved.getId())
                .productId(saved.getProductId())
                .quantity(saved.getQuantity())
                .status(saved.getStatus())
                .totalPrice(saved.getTotalPrice())
                .message("Order completed successfully")
                .build();
    }
}
