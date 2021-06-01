
# Using readlines() 
file1 = open('input.txt', 'r') 
Lines = file1.readlines() 
  
count = 0
myset = set()
mylist = []

for line in Lines: 
		for i in range(3):
			c = line[i]
			myset.add(c);
	
while(True):
	
	not1 = myset.copy()
	print("myset", myset)

	if(len(myset) == 1):
		mylist.append(myset.pop())
		break;
		
	for line in Lines: 
		for i in range(1, 3):
			c = line[i]
			not1.discard(c);
			if(len(not1) == 1):
				one = not1.pop()
				mylist.append(one)
				myset.discard(one);
				break
	
	print("password sofar ", mylist)
print("password is ", mylist)

	