/* IDENT framebuffer pen animation, fbdev 16/24/32bpp, no external libs. */
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
typedef struct {float x,y;} Pt;
typedef struct {Pt a,b;} Line;
/* Vector letters: every line is revealed progressively by a moving pen. */
static const Line strokes[]={
{{0,0},{1,0}},{{.5f,0},{.5f,2}},{{0,2},{1,2}},
{{1.5f,0},{1.5f,2}},{{1.5f,0},{2.2f,0}},{{2.2f,0},{2.5f,.3f}},{{2.5f,.3f},{2.5f,1.7f}},{{2.5f,1.7f},{2.2f,2}},{{2.2f,2},{1.5f,2}},
{{3,0},{3,2}},{{3,0},{4,0}},{{3,1},{3.85f,1}},{{3,2},{4,2}},
{{4.5f,2},{4.5f,0}},{{4.5f,0},{5.5f,2}},{{5.5f,2},{5.5f,0}},
{{6,0},{7,0}},{{6.5f,0},{6.5f,2}}
};
typedef struct {uint8_t *mem;size_t length;struct fb_var_screeninfo v;struct fb_fix_screeninfo f;} Fb;
static uint32_t col(uint8_t r,uint8_t g,uint8_t b,const Fb *fb){
 const struct fb_var_screeninfo *v=&fb->v;
 return (((uint32_t)(r>>(8-v->red.length)))<<v->red.offset)|
        (((uint32_t)(g>>(8-v->green.length)))<<v->green.offset)|
        (((uint32_t)(b>>(8-v->blue.length)))<<v->blue.offset);
}
static void pixel(Fb *fb,int x,int y,uint32_t c){
 if(x<0||y<0||x>=(int)fb->v.xres||y>=(int)fb->v.yres)return;
 size_t idx=(size_t)(y+fb->v.yoffset)*fb->f.line_length+(size_t)(x+fb->v.xoffset)*(fb->v.bits_per_pixel/8);
 if(idx+fb->v.bits_per_pixel/8>fb->length)return;
 if(fb->v.bits_per_pixel==16){uint16_t a=(uint16_t)c;memcpy(fb->mem+idx,&a,2);}
 else if(fb->v.bits_per_pixel==24){for(int i=0;i<3;i++)fb->mem[idx+i]=(uint8_t)(c>>(i*8));}
 else {memcpy(fb->mem+idx,&c,4);}
}
static void disk(Fb *fb,int x,int y,int radius,uint32_t c){
 for(int j=-radius;j<=radius;j++)for(int i=-radius;i<=radius;i++)
  if(i*i+j*j<=radius*radius)pixel(fb,x+i,y+j,c);
}
static void line(Fb *fb,int x1,int y1,int x2,int y2,int r,uint32_t c){
 int dx=x2-x1,dy=y2-y1,steps=abs(dx)>abs(dy)?abs(dx):abs(dy);
 if(!steps){disk(fb,x1,y1,r,c);return;}
 for(int i=0;i<=steps;i++)disk(fb,x1+dx*i/steps,y1+dy*i/steps,r,c);
}
static void rest(int ms){struct timespec t={ms/1000,(long)(ms%1000)*1000000};nanosleep(&t,NULL);}
int main(int argc,char **argv){
 int attempts=2,delay=12;
 if(argc>1){attempts=atoi(argv[1]);if(attempts<1||attempts>5)return 2;}
 if(argc>2){delay=atoi(argv[2]);if(delay<1||delay>100)return 2;}
 const char *device=getenv("IDENTIUM_FB_DEVICE");if(!device||!*device)device="/dev/fb0";
 int fd=open(device,O_RDWR|O_CLOEXEC);if(fd<0){perror("framebuffer");return 1;}
 Fb fb={0};
 if(ioctl(fd,FBIOGET_VSCREENINFO,&fb.v)||ioctl(fd,FBIOGET_FSCREENINFO,&fb.f)){perror("fb ioctl");close(fd);return 1;}
 if((fb.v.bits_per_pixel!=16&&fb.v.bits_per_pixel!=24&&fb.v.bits_per_pixel!=32)||
    fb.v.xres<320||fb.v.yres<200||fb.f.type!=FB_TYPE_PACKED_PIXELS||
    fb.v.red.length>8||fb.v.green.length>8||fb.v.blue.length>8||!fb.f.smem_len){close(fd);return 1;}
 fb.length=fb.f.smem_len;
 fb.mem=mmap(NULL,fb.length,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
 if(fb.mem==MAP_FAILED){perror("fb mmap");close(fd);return 1;}
 float scale=fminf((float)fb.v.xres/10.f,(float)fb.v.yres/5.f);
 int left=(int)((fb.v.xres-7.f*scale)*.5f),top=(int)((fb.v.yres-2.f*scale)*.5f);
 uint32_t white=col(230,240,255,&fb),bg=col(9,17,30,&fb);
 int radius=(int)(scale*.04f);if(radius<1)radius=1;if(radius>7)radius=7;
 for(int a=0;a<attempts;a++){
  for(int y=0;y<(int)fb.v.yres;y++)for(int x=0;x<(int)fb.v.xres;x++)pixel(&fb,x,y,bg);
  for(size_t n=0;n<sizeof(strokes)/sizeof(strokes[0]);n++){
   Line v=strokes[n];int x1=left+(int)(v.a.x*scale),y1=top+(int)(v.a.y*scale);
   int x2=left+(int)(v.b.x*scale),y2=top+(int)(v.b.y*scale);
   for(int step=1;step<=10;step++){
    int ex=x1+(x2-x1)*step/10,ey=y1+(y2-y1)*step/10;
    int sx=x1+(x2-x1)*(step-1)/10,sy=y1+(y2-y1)*(step-1)/10;
    line(&fb,sx,sy,ex,ey,radius,white);rest(delay);
   }
  }
  rest(170);
 }
 munmap(fb.mem,fb.length);close(fd);return 0;
}
