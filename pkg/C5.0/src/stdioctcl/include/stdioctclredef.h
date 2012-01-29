/*
 Copyright (C) 2011-2012, Nathan Coulter and others 

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _STDIOCTCLREDEF

#ifndef _STDIOCTCL
#error stdioctl.h must be included before stdioctclredef.h
#endif /* _STDIOCTCL */

#ifdef getc
#undef getc
#endif
#ifdef putc
#undef putc
#endif

#ifdef stdin
#undef stdin
#endif
#ifdef stdout
#undef stdout
#endif
#ifdef stderr
#undef stderr
#endif

#define stdin stdioctcl_stdin
#define stdout stdioctcl_stdout
#define stderr stdioctcl_stderr

#define fopen stdioctcl_fopen
#define fclose stdioctcl_fclose
#define feof stdioctcl_feof
#define fflush stdioctcl_fflush
#define fgetc stdioctcl_fgetc
#define fgets stdioctcl_fgets
#define fprintf stdioctcl_fprintf
#define fputc stdioctcl_fputc
#define fputs stdioctcl_fputs
#define fread stdioctcl_fread
#define fwrite stdioctcl_fwrite
#define getc stdioctcl_fgetc
#define putc stdioctcl_fputc
#define putchar stdioctcl_putchar
#define rewind stdioctcl_rewind

#define _STDIOCTCLREDEF
#endif  /* _STDIOCTCLREDEF */
