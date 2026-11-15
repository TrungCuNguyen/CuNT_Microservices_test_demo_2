package api.apigateway.filter;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Component
@RequiredArgsConstructor
public class LoggingFilter implements GlobalFilter, Ordered {
    private static final Logger log = LoggerFactory.getLogger(LoggingFilter.class);
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String time = LocalDateTime.now().format(FORMATTER);
        String method = exchange.getRequest().getMethod().name();
        String uri = exchange.getRequest().getURI().toString();

        String logMessage = String.format("[GATEWAY GLOBAL FILTER] Time: %s | Method: %s | URI: %s", time, method, uri);
        System.out.println(logMessage);
        log.info(logMessage);

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
