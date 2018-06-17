# Como trabajar

## Si es tu primera vez:

```bash
# Si usas https
$ git clone https://github.com/german1608/hissam-estatica.git
# Si usas SSH
$ git clone git@github.com:german1608/hissam-estatica.git
```
## Cuando empieza el dia

```bash
$ git checkout master
$ git fetch origin
$ git rebase origin/master
$ npm install
$ git checkout tu-rama

# El siguiente comando puede que genere conflictos.
# Toca arreglarlos a mano (git te dice donde).
$ git rebase master
```

### Explicacion de cada comando

1) `git checkout master`: Nos vamos a la rama principal, `master`.
2) `git fetch origin`: Le decimos a git que traiga todos los cambios del
repo remoto **PERO** que no los aplique sobre nuestro repo local.
3) `git rebase origin/master`: Esto es como un merge, pero mas limpio. Lo que
hace `git rebase <branch-name>` es que aplica los cambios mas recientes _por encima_ de
\<branch-name>. Es complicadito, se los explico con mas detalle luego.
4) `npm install`: Si alguien actualizo el package.json, i.e anadio mas dependencias,
esto nos las instalara automaticamente.
En resumen, esto aplica los cambios mas actuales a tu `master`.
5) `git checkout tu-rama`: Cambias a tu rama de trabajo.
6) `git rebase master`: Aplica los cambios mas actuales sobre tu rama de trabajo. 

## Mientras trabajas

**SIEMPRE** trabajen sobre un branch distinto al `master`. Es decir, entrando
en algo de contexto, si quiero desarrollar el header de la pagina haria algo asi:

```bash
# Si no he creado el branch
$ git branch header-dev

# Cambiamos al branch
$ git checkout header-dev

# Commiteamos blablabla...
```

La razon principal de no trabajar sobre el `master` es por que ese es el codigo
principal, el que tiene todos los cambios. Ademas, lo bueno de trabajar con branches
es que si no te gusta lo que estabas codeando o sencillamente ya no es util, pues
puedes eliminar el branch sin danar el codigo principal, cosa que no podria
suceder si hubieras commiteado directamente sobre el master.

## Cuando quieres subir cambios

Lo bueno de agregarlos a colaboradores, es que todos tienen permisos de escritura
sobre el remoto principal. Sin embargo, hay que seguir unas reglas para que no
se nos complique la vida.

```bash
# ...
# Commitee todos los cambios de mi codigo
# Cerciorarse de tener el __working directory__ limpio.

# Aqui repetimos TODO lo de "Cuando empieza el dia". Esto es para evitar
# conflictos
$ git push -u origin tu-rama
```

Luego, en la interfaz de github le dan a pull-request. Si no les aparece eso en
ningun sitio, cambian el branch en la interfaz y ahi deberia aparecerles.

Es muy importante que la decision de hacer un merge se haga de manera grupal.
Que se analize bien si de verdad esos cambios no joden, ya que esos son los
cambios que van al `master`.

Cuando se abre un pull request (de ahora en adelante, PR), en la interfaz de github
les aparecera una notificacion en la pestana _Pull Requests_. Ahi veremos TODAS
las PR de nuestro proyecto y en cada una se puede hacer click para ver los
commits y los comentarios de nosotros. Cuando se decida que el PR es correcto
y que se debe mergear, me dicen y la mergeo. Yo soy el dueno del repo y soy el
puede mezaclar branches.
