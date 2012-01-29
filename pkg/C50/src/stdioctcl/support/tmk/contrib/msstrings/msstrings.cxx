#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER (1024*1024*16)
char* tmp_buffer;

int main(int argc,char** argv)
{
  FILE* f;
  
  if(argc==2)
    f=fopen(argv[1],"rb");
  else
	exit(0);

  if(f==NULL)
    exit(0);
  
  tmp_buffer=(char*)malloc(1+BUFFER);
  
  size_t bytes = fread(tmp_buffer,1,BUFFER,f);
  
  for(unsigned int i=1;i<bytes;i++)
    {
      if(tmp_buffer[i] == '\0')
	{
	  unsigned int j;
	  for(j=i-1;j!=0 && tmp_buffer[j] != '\0' && isprint(tmp_buffer[j]);j--);
	  if(i-j > 4)
	    printf("%s\n",&tmp_buffer[j+1]);
	}
    }
  
  free(tmp_buffer);
  fclose(f);
  return 0;
  
}


