
Create animated from from PNG

```
convert -resize 3360x2100! -delay 100 -loop 5 -dispose previous *.png arcion-demo.gif

convert -resize 3360x2100! -delay 100 -loop 5 -dispose previous -fuzz 10% -layers Optimize *.png arcion-demo.gif



```