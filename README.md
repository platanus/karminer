# Karminer

Las sospechas de corrupción por parte de los mantenedores de HAM nos han obligado a implementar una solución con la tecnología Blockchain para registrar el karma de cada individuo.

Cada grupo debe implementar un nodo minero usando TDD.

Básicamente un minero deberá:
  * escuchar nuevas transacciones, validarlas e intentar minarlas.
  * escuchar nuevos bloques, validarlos y actualizar los balances.

Se usarán funciones criptográficas de curva elíptica, se recomienda usar la gema `bitcoin-ruby` para esto.

## Scafolding

```
# Install dependencies
brew bundle install
bundle install

# Run tests with guard
guard
```

## Protocolo

Proveeremos un servidor pubsub a los que se conectaran los nodos/mineros

```
52.55.173.152:6379
```

Para conectarse se recomienda usar la gema `redis`

```
redis = Redis.new(url: "redis://52.55.173.152:6379")

# para escuchar:

redis.subscribe("pagos") do |on|
  on.message do |channel, message|
    pago = JSON.parse(message)
  end
end

redis.subscribe("bloques") do |on|
  on.message do |channel, message|
    bloque = JSON.parse(message)
  end
end

# para enviar bloques

redis.publish 'bloques', [{ ... }, { ... }].to_json

```

Existirán 2 canales:

**pagos**: los eventos corresponden a nuevas transacciones

```
{
  "de": "0xABCD",       // llave pública compacta del que manda
  "nonce": 0,           // nonce del pago, debe ser mayor al último nonce de `pago.de`
  "para": "0xABCD",     // llave pública compacta del que recibe
  "karma": 123,         // monto entero
  "piticlines": 1,      // propina pal minero
  "firma": "0xABCD"     // firma_ec_compacta(SHA256("{de}{para}{piticlines}"), llave_privada_del_que_manda)
}
```


Para el cálculo de la firma en ruby se puede usar la gema `bitcoin-ruby` (ya incluida en el proyecto):

```ruby
Bitcoin::OpenSSL_EC.sign_compact(Digest::SHA256.digest("{de}{para}{piticlines}"), llave_privada_hex)
```

**bloques**: los eventos corresponden a nuevos estados del blockchain completo (cada vez que hay un nuevo bloque)

```
[
  ...,
  {
    "hash_anterior": "0xABCD",  // hash bloque anterior
    "pago": {
      // pago minado
    },
    "numerito": 133,            // numerito Proof of Work
    "minero": "0xABCD",         // llave pública compacta del minero que minó, aquí se abona la recompensa + la propina
    "hash": "0xABCD"            // SHA256("{hash_anterior}{hash_pago}{minero}{numerito}")
  }
]
```

## Reglas

1. Toda 'dirección' parte con 1000 de Karma.

2. Se deben validar un pago antes de minarlo.

2.1. Se debe validar que `pago.karma + pago.piticlines > balance(pago.de)`.

2.2. Se debe validar que `pago.nonce > ultimo_nonce(pago.de)`.

2.3. Se debe validar que `recover_compact(pago.firma, SHA256("{de}{para}{piticlines}") == pago.de`.

2.4. Para minar un pago se debe encontrar un `numerito` tal que

```ruby
base58(SHA256("{bloque.hash_anterior}{hash_pago}{bloque.minero}{bloque.numerito}")).donwcase.end_with?('frog')
```

Donde `hash_pago = SHA256("{de}{para}{piticlines}")`

3. Cada vez que llega una actualización del bloque, se deben procesar los bloques nuevos (bloques después del último bloque conocido). Si el hash del último bloque conocido no se conoce y la cadena es más larga que la conocida, entonces se debe validar desde el bloque 0.

4. Cada vez que llega una actualización del bloque, por cada bloque nuevo (bloques después del último bloque conocido)

4.1 Se debe validar que `bloque.pago` sea válido (según 2, 3, 4 )

4.2 Se debe validar que `bloque.hash` esté correctamente calculado según 2.4.

4.3 Se debe validar que `bloque.hash_anterior` sea igual al último hash de un bloque válido (o 0x0 si es el primer bloque).

5. Cada vez que se recibe un bloque válido

5.1 Se debe restar `pago.karma + pago.piticlines` a `balance(pago.de)`

5.2 Se debe sumar `pago.karma` a `balance(pago.para)`

5.3 Se debe sumar `pago.piticlines` a `balance(bloque.minero)`

5.4 Se debe actualizar el último bloque válido

5.5 Si se está minando se debe reemplazar el `hash_anterior` por el hash del nuevo bloque obtenido.

5.6 Si se está minando se debe revisar que el **pago** que está siendo minado no corresponde al pago del bloque recién minado.

6. Cada vez que se recibe un bloque inválido se debe mostrar el address del minero que intentó empujarlo.

## Aclaraciones

Cada nodo deberá mostrar en todo momento el balance de todas las cuentas que conoce.

Las transacciones serán gatilladas ‘a mano’ por los usuarios roñosos.
