library(tm)
library(sna)

# document term matrix 만들기
sales = read.csv('c:/users/sbh0613/data/1차종합전처리.csv',header=T)
names(sales)
dim(sales)
sales.con = paste(sales$문의개요,sales$접수내용)
sales.con = as.matrix(sales.con)
sales.cor = Corpus(VectorSource(sales.con))
sales.dtm = DocumentTermMatrix(sales.cor)
dim(sales.dtm)
inspect(sales.dtm[5883,1:10])

# 쓸데 없는 말이 좀 많다. 그러면 각 행마다 명사추출을 한 것으로 document term matrix을 만든다면??


library(rJava)
library(KoNLP)
library(tm)
library(stringr)

.libPaths()
useSejongDic()
options(mc.cores=1)

setwd('c:/users/sbh0613/data')

sales <- read.csv('1차종합전처리.csv',header=T)
content <- sales[,which(names(sales)=='접수내용')]
content <- as.vector(content)

#명사 추출하여 백터를 뽑아내는 함수 만들기
words = function(doc){
		if (doc == '' | doc == "['']" | doc == "[' ']"){
		return('')
}
		doc = as.character(doc)
		doc2 = SimplePos22(doc)
		doc3 = str_match(doc2,"[가-힣]+/NC")
		doc4 = na.omit(doc3)
		for(i in 1:nrow(doc4)){
		doc4[i] = strsplit(doc4[i],'/')[[1]][1]
}
		return(as.vector(doc4))
}

#각 행마다 접수내용 칼럼의 명사 추출해서 리스트에 담기.
list.noun = list()
for (i in 1:nrow(sales)){
		list.noun[[i]] = words(content[i])
}


length(list.noun)

fileConn <- file("mydata.txt")
writeLines(sales$접수내용명사추출[1:5883], fileConn)
close(fileConn)

noun.txt = readLines('mydata.txt')

noun.cor = Corpus(VectorSource(noun.txt))
noun.dtm = DocumentTermMatrix(noun.cor)
dim(noun.dtm)
#차원이 훨씬 줄어들었다!
inspect(noun.dtm)

#term 중에서 100번 이상 나온 애들만 추려보면 581개가 나옴. 46000개 중에서. 걔네들로 다시 행렬 만들어 보기.
sales.n.m = as.matrix(noun.dtm)

freq.noun = colSums(sales.n.m)

sales.n.m.over.100 = sales.n.m[,freq.noun>1000]

dim(sales.n.m.over.100)


#pca 살짝 해보기
sales.pca = prcomp(sales.n.m.over.100,center=TRUE,scale=TRUE)

plot(sales.pca,type='l')

summary(sales.pca)

????




# correlation matrix을 이용하여 network 시각화 해보기.

library(qgraph)

cormat = cor(sales.n.m.over.100)

#한국어 칼럼 영어로 바꿔주기

fileconnet = file('colnames.txt')
writeLines(colnames(cormat),fileconnet)
close(fileconnet)

english.name = readLines('colnames.txt')
english.name = english.name[-1]

cormat.eng = cormat

colnames(cormat.eng) = english.name
rownames(cormat.eng) = english.name

corr.net = qgraph(cormat.eng, minimum=0.3, vsize=4,layout='spring', labels = row.names(cormat.eng))
#centrality
a node is central / important / influential if..
- it has many connections (degree / strength)
- it is close to all other nodes (closeness)
- it connects other nodes (betweenness)

# degree 살펴보기

cent.corr = centrality(corr.net)

as.data.frame(sort(cent.corr$OutDegree,decreasing=TRUE))

# degree 가장 높은 3개로 다중 선형 회귀 실시하기

sales.term = as.data.frame(sales.n.m.over.100)
names(sales.term) = colnames(sales.n.m.over.100)

sales.marketing = sales.term[c('홍보','수립', '방안', '추진', '매체', '활용', '오프라인', '온라인', '제작', '기획', '주요')]
sales.planning = sales.term[c('기획','수립', '홍보', '제작', '이벤트', '콘텐츠', '운영', '관리', '대상')]
sales.making = sales.term[c('제작','홍보', '활용', '온라인', '이벤트', '콘텐츠', '운영', '관리', '기획')]

fit.marketing = lm(홍보~. , data=sales.marketing)
summary(fit.marketing)

fit.planning = lm(기획~., data=sales.planning)
summary(fit.planning)

fit.making = lm(제작~., data=sales.making)
summary(fit.making)

# success 명사 살펴보기

success.index = which(sales$결과 == 'success')


suc.df = data.frame(x=rep(0,length(success.index)))
for (i in 1:length(success.index)){
suc.df$x[i] = toString(list.noun[[success.index[i]]])
}


file.suc = file("success.txt","w")
for (i in 1:1022){
write(suc.df$x[i],file.suc,append=TRUE)
}
close(file.suc)

list.noun.success = readLines("success.txt")

noun.cor.suc = Corpus(VectorSource(list.noun.success))
noun.dtm.suc = DocumentTermMatrix(noun.cor.suc)
dim(noun.dtm.suc)
inspect(noun.dtm.suc)


#term 중에서 100번 이상 나온 애들만 추려보면 70개가 나옴. 12349개 중에서. 걔네들로 다시 행렬 만들어 보기.
sales.suc = as.matrix(noun.dtm.suc)

freq.noun.suc = colSums(sales.suc)

sales.suc.100 = sales.suc[,freq.noun.suc>100]

dim(sales.suc.100)

sales.suc.100[1:5,1:10]

cormat.suc = cor(sales.suc.100)

cormat.suc[1:5,1:5]
corr.suc = qgraph(cormat.suc, minimum=0.3, vsize=4,layout='spring', labels = row.names(cormat.suc),filetype="jpeg")


cent.suc = centrality(corr.suc)

as.data.frame(sort(cent.suc$OutDegree,decreasing=TRUE))


# cancelled, failed, holding, pending, tie-in failed 명사 살펴보기

fail.index = which(sales$결과 == 'cancelled' | sales$결과 == 'failed' | sales$결과 == 'holding' | sales$결과 ==  'pending' | sales$결과 == 'tie-in failed')  

fail.df = data.frame(x=rep(0,length(fail.index)))
for (i in 1:length(fail.index)){
fail.df$x[i] = toString(list.noun[[fail.index[i]]])
}


file.fail = file("fail.txt","w")
for (i in 1:1308){
write(fail.df$x[i],file.fail,append=TRUE)
}
close(file.fail)

list.noun.fail = readLines("fail.txt")

noun.cor.fail = Corpus(VectorSource(list.noun.fail))
noun.dtm.fail = DocumentTermMatrix(noun.cor.fail)
dim(noun.dtm.fail)
inspect(noun.dtm.fail)

#term 중에서 100번 이상 나온 애들만 추려보면 70개가 나옴. 12349개 중에서. 걔네들로 다시 행렬 만들어 보기.
sales.fail = as.matrix(noun.dtm.fail)

freq.noun.fail = colSums(sales.fail)

sales.fail.100 = sales.fail[,freq.noun.fail>150]

dim(sales.fail.100)

cormat.fail = cor(sales.fail.100)
corr.fail = qgraph(cormat.fail, minimum=0.3, vsize=4,layout='spring', labels = row.names(cormat.fail),filetype="jpeg")


cent.fail = centrality(corr.fail)

as.data.frame(sort(cent.fail$OutDegree,decreasing=TRUE))

unique(sales$결과)

save.image()

# 분석,활용에 대한 회귀분석
sales.suc.term = as.data.frame(sales.suc.100)
names(sales.suc.term) = colnames(sales.suc.term)


sales.분석 = sales.suc.term[c('분석', '이슈', '기획', '제작', '실행', '이벤트', '제시', '홍보', '활용', '주요', '수립')]
sales.활용 = sales.suc.term[c('활용', '주요', '수립', '분석', '제작', '홍보', '제시', '전략', '매체', '관련')]


lm.분석 = lm(분석~. , data=sales.분석)
summary(lm.분석)

lm.활용 = lm(활용~. , data=sales.활용)
summary(lm.활용)

엑셀 파일에서, csv 파일로 저장할 때 뭔가 인코딩 오류가 난 것 같다.
csv 파일로 저장해서 r에서 read.csv로 불러왔을 때, 여기에 있는 데이터를 그대로 쓰면
인코딩 오류가 나는데,
얘를 다시 txt 파일에 쓰고 얘를 다시 그대로 불러오면 오류가 없다.
