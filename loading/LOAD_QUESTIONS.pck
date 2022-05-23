CREATE OR REPLACE PACKAGE "LOAD_QUESTIONS" AS

  function add_question( iid_task in number,
                        itheme_number in number,
                        ipartition_number in number, 
                        isubpartition_number in number, 
                        iorder_num in number, 
                        iurl_image in varchar2, 
                        iquestion in nvarchar2) return varchar2;
  procedure add_answer(iid_question in number, 
                       iorder_num_answer in number, icorrectly in char, 
                       ianswer in nvarchar2);

END LOAD_QUESTIONS;
/
CREATE OR REPLACE PACKAGE BODY "LOAD_QUESTIONS" AS

  function add_question( iid_task in number, 
                        itheme_number in number,
                        ipartition_number in number, 
                        isubpartition_number in number, 
                        iorder_num in number, 
                        iurl_image in varchar2, 
                        iquestion in nvarchar2) return varchar2 
  AS
    id pls_integer;
  begin
    id := seq_quest.nextval;
    insert into questions_proto q (id_question, active, id_task, theme_number, 
                        partition_number, 
                        subpartition_number, 
                        order_num_question,
                        url_image, question)
           values ( id, 'Y', iid_task, itheme_number, 
                    ipartition_number, isubpartition_number, 
                    iorder_num, iurl_image, iquestion);
    return id;
  END add_question;


  procedure add_answer(iid_question in number, 
                       iorder_num_answer in number, icorrectly in char, 
                       ianswer in nvarchar2)
  is
  begin
    insert into answers_proto q (id_answer, active, id_question, order_num_answer, correctly, answer)
            values ( seq_answer.nextval, 'Y', iid_question, iorder_num_answer, icorrectly,
              ianswer);
  end add_answer;

  procedure activate
  is
  begin
    update questions q set active = 'N';
    update answers q set active = 'N';
    insert into questions select * from questions_proto;
    insert into answers select * from answers_proto;
    commit;    
  end activate;


END LOAD_QUESTIONS;
/
