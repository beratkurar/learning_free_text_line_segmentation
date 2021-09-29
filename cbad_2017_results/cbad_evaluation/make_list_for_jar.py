import os

predicts_folder=('predicts/')
truths_folder=('truths/')
predict_files=os.listdir(predicts_folder)

predicts_list=open('predicts.lst', 'w')
truths_list=open('truths.lst', 'w')

for predict_file in predict_files:
    predicts_list.write(predicts_folder+predict_file+'\n')
    truths_list.write(truths_folder+predict_file[:-4]+'.jpg'+predict_file[-4:]+'\n')
predicts_list.close()
truths_list.close()
