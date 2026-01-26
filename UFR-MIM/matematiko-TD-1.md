# Mathematiques TD 1

> En mathématique, il n'y a pas une réponse simple que quoi s'agit d'une forme simplifé. Selon le contexte, ça peut-être un polynomial développé avec les pouvoirs en ordre ascendant, un produit de plusieurs polynomials, ou autrement.

## Quelques dérivés intéressants

$f(x)= \frac{uv}{w}\Rightarrow f'(x)=\frac{(uv)'w-uv(w)'}{w^2}=\frac{(u'v+uv')'w-uvw'}{w^2}$
où $u,v,w$ sont fonctionnes de $x$ 

## Exercice 1

1. $f'(x)=36x^8+18x^5+24x^2-35x^4$
ensemble de définition $D_f$ : $\{x \in R\}$
ensemble de dérivabilité $D_{f'}$ : $\{x \in R\}$

2. $f(x)=x^{-2}-x^{-6}+3ln(x) \Rightarrow f'(x)=-2x^{-3}+6x^{-7}+\frac{1}{3}$
ensemble de définition $D_f$ : $\{x \in R | x>0 \}$
ensemble de dérivabilité $D_{f'} : $ $\{x \in R | x>0 \}$

3. Notons $u=x^3+x^{-1}, v=x^\frac{1}{2}$
$ \Rightarrow u'=3x^{2}-x^{-2}, v'=\frac{1}{2}x^{-\frac{1}{2}}$
$ f(x)=-(uv) \Rightarrow f'(x)= -(uv'+u'v)=-[(x^3+x^{-1})(\frac{1}{2}x^{-\frac{1}{2}})+(3x^{2}-x^{-2})(x^\frac{1}{2})]$
$=-[\frac{1}{2}x^{2.5}+\frac{1}{2}x^{-1.5}+3x^{2.5}-x^{-1.5}]$
$=-3.5x^{2.5}+0.5x^{1.5}$
ensemble de définition $D_f$: $\{x \in R | x>0 \}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R | x>0 \}$


4. Notons $u=-x^4+\frac{2}{7}x^2-\frac{20}{103}, v=\frac{1}{3}x^3-3x^2+6x-2$
$\Rightarrow u'=4x^3+\frac{4}{7}x, v'=x^2-6x+6$
$ f(x)=uv \Rightarrow f'(x)= uv'+u'v=(-x^4+\frac{2}{7}x^2-\frac{20}{103})(x^2-6x+6)+(4x^3+\frac{4}{7}x)(\frac{1}{3}x^3-3x^2+6x-2)$
ensemble de définition $D_f$: $\{x \in R \}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R \}$

5. Notons $u=-5, v=x^2+2x+3$
$\Rightarrow u'=0, v'=2x+2$
$ f(x)=\frac{u'}{v} \Rightarrow f'(x)=\frac{u'v-uv'}{v^2}$
$=\frac{5(2x+2)}{(x^2+2x+3)^2}$
$=\frac{10x+10}{x^4+4x^3+10x^2+12x+9}$
Remarquons $v=(x+1)^2+2>0$
ensemble de définition $D_f$: $\{x \in R\}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R \}$

6. similar à 4
Notons $u=x^2, v=cos(x)$
$\Rightarrow u'=2x, v'=-sin(x)$
$ f(x)=uv \Rightarrow f'(x)= uv'+u'v=(x^2)(-sin(x))+(2x)(cos(x))=2xcos(x)-x^2sin(x)$
ensemble de définition $D_f$: $\{x \in R \}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R \}$

7. similar à 5
Notons $u=2x+1, v=x^2+1$
$\Rightarrow u'=2, v'=2x$
$ f(x)=\frac{u'}{v} \Rightarrow f'(x)=\frac{u'v-uv'}{v^2}$
$=\frac{(2)(x^2+1)-(2x+1)(2x)}{(x^2+1)^2}$
$=\frac{2x^2+2-(4x^2+2x)}{(x^2+1)^2}$
$=\frac{-2x^2-2x+2}{x^4+2x^2+1}$
ensemble de définition $D_f$: $\{x \in R\}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R \}$
8. similar à 5,7
9. Notons $x\sqrt{x}=x^{1.5}$, il n'y a donc aucune distinction matérielle entre 9 et 5,7,8.
10. Notons $(x+8)\sqrt{x}=x^{1.5}+8x^{0.5}$, il n'y a donc aucune distinction matérielle entre 9 et 5,7,8,9.

> Il est également possible d'utiliser $f(x)= \frac{uv}{w}\Rightarrow f'(x)=\frac{(uv)'w-uv(w)'}{w^2}=\frac{(u'v+uv')'w-uvw'}{w^2}$

ensemble de définition $D_f$: $\{x \in R | x \geq 0 \}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R | x > 0\}$

> Notons $\sqrt{x}$ n'est pas dérivable à x=0 car $(\sqrt{x})'=\frac{1}{\sqrt{x}}=\frac{1}{0}$ lors $x=0$

11. $f(x)=x^{-3}+\frac{cox(x)}{sin(x)}$
Astuce : $(u+v)'=u'+v'$

ensemble de définition $D_f$: $\{x \in R | x \neq k\pi, k \in Z \}$
ensemble de dérivabilité : $D_{f'}$ $\{x \in R | x \neq k\pi, k \in Z \}$


## Exercice 2

1. $f(g(x))=f(\sqrt{x})=\frac{1}{\sqrt{x}}=x^{-0.5}$
ensemble de définition $D_f$: $\{x \in R | x > 0 \}$
$g(f(y))=g(\frac{1}{y})=\sqrt{\frac{1}{y}}={y}^{-0.5}$
ensemble de définition $D_f$: $\{y \in R | y > 0 \}$

2. $f(g(x))=(\frac{x}{x+1})^2+(\frac{x}{x+1})=\frac{x}{x+1}(\frac{x}{x+1}+1)=\frac{x}{x+1}(\frac{2x+1}{x+1})=\frac{2x^2+x}{x^2+2x+1}$
ensemble de définition $D_f$: $\{x \in R | x \neq -1 \}$
$g(f(y))=\frac{(y^2+y)}{(y^2+y)+1}=\frac{y^2+y}{y^2+y+1}$
ensemble de définition $D_f$: $\{y \in R \}$ (remarquons que $y^2+y+1=(y+\frac{1}{2})^2+\frac{3}{4}>0$)

3. Similaire à 1 et 2. 

> Nous remarquons que $f(g(x)) \not\equiv g(f(x))$, mais **occasionnellement** $f(g(x)) = g(f(x))$
>
> Un bon exemple d'intuition : $f(x)=cos(x^2)$ et $f(x)=cos^2(x)$

## Exercice 3

1. $f(x)=g(h(x))$, où $g(y)=\frac{1}{y}, h(x)=3x-1$
ensemble de définition $D_f$: $\{x \in R | x \neq \frac{1}{3} \}$
2. $f(x)=g(h(x))$, où $g(y)=y^{0.5},h(x)=4-x^2$
ensemble de définition $D_f$: $\{x \in R |\ |x| \leq 2 \}$
3. $f(x)=g(h(m(x)))$, où $g(y)=ln(y), h(z)=z+2, m(x)=e^x$
$\because e^x > 0$
$\therefore y=e^x+2 > 0$
remarque $ln(y)$ est défini pour $]0,\infty[$,
$\therefore$ ensemble de définition $D_f$: $\{x \in R\}$ ))
4. $f(x)=g(h(x))$, où $g(y)=cos(y),h(x)=x^2$
5. $f(x)=g(h(x))$, où $g(y)=y^2, h(x)=cos(x)$
6. $f(x)=g(h(x))$, où $g(y)=cos(y), h(x)=\frac{x-1}{2x+1}$
7. $f(x)=g(h(x))$, où $g(y)=ln(y), h(x)=\frac{x+1}{2x^2+3}$
8. $f(x)=g(h(x))$, où $g(y)=(y^{0.5}-2)ln(y), h(x)=(x+2)^2$ ))
9. $f(x)=g(h(m(x)))$, où $g(y)=e^y,h(z)=z^{0.5}+3,m(x)=x^2+1$