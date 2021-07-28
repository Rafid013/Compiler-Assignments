int x,y,z; float a;

int test1(int,int,float);

int test2(int a,int b){
	return a;
}

int test1(int a,int b){
}

int test1(int a,int b,int c){
}

void test1(int a,int b,float c){
}

int test1(int a,int b,float b){
	float a;
}

void test2(int a,float a,int b){
}

void test3(int a,float b,int c){
	float a;
}

void test4(){
}

void test6(int a){
	int b[2];
	b[1]=50;
	{
		int a;int b[2];
		a=1;b[1]=2;
		{
			int a;int b[2];
			a=3;b[1]=4;
			{
				int a;int b[2];
				a=5;b[1]=6;
				
			}
		}
	}
}

void test7(){
	int b[2];
	b[1]=50;
	{
		int a;int b[2];
		a=1;b[1]=2;
		{
			int a;int b[2];
			a=3;b[1]=4;
			{
				int a;int b[2];
				a=5;b[1]=6;
				
			}
		}
	}
}

void test8(int a){
	float b;
	int b,c,d;
	float c[50];
}

int main(){
	int a,b,c,d[5],e[5],f;
	float g[6],h;
	test6(1,2);
	test6(1.5);
	b=5%0;
	c=2.5%2.5;
	d=4/0;
	f=4/0;
	f=2 && 9;
	e[2]=f;
	e[3]=h;
	d[4]=(1*2)+(529/23)-(75213%38*45-56/28&&23+47);
	d[7]=(1*2)+(529/23)-(75213%38*45-56/28&&23+47);
	e[0]=!d[4];
	return 0;

}
