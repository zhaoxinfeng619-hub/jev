from http.server import HTTPServer, BaseHTTPRequestHandler
import json
class Handler(BaseHTTPRequestHandler):
 def do_POST(self):
  body=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
  if self.path == '/chat/completions':
   assert self.headers['Authorization'] == 'Bearer generator-test-key'
   assert body['model'] == 'test-generator'
   state=json.loads(body['messages'][1]['content'])
   assert '最新待回复的对方消息：Tell me what happened?' in state['ocr'] and '【我】Tell me more' in state['ocr'] and state['recentSuggestions'] == ['Old suggestion']
   replies=[dict(style=style,shortReply=short,detailedReply=short+' 你接着说，我听着。',reason='根据朋友提到的雨和伞自然接话') for style,short in [('自然','那把伞后来找到了吗？'),('关心','淋湿了难不难受呀？'),('幽默','这场雨还挺会挑时间的哈哈'),('简短','后来怎么回去的？')]]
   self.respond({'choices':[{'message':{'content':json.dumps({'replies':replies},ensure_ascii=False)}}]})
   return
  assert self.path == '/v1/systemone' 
  assert self.headers['Authorization'] == 'Bearer test-key'
  assert body['model'] == 'test-jev'
  assert set(body['questions']) == {'intent','emotion','reply','can_reply'}
  assert '最新待回复的对方消息：Tell me what happened?' in body['state']['ocr'] and '【我】Tell me more' in body['state']['ocr']
  dynamic='candidate_1' in body['questions']['reply']['criteria']
  if dynamic: assert body['questions']['reply']['criteria']['candidate_1']['shortReply'] == '那把伞后来找到了吗？'
  else: assert body['questions']['reply']['criteria']['interest']['shortReply']
  choice=lambda value:dict(type='choice',choice=value,confidence=0.9,probabilities={value:1.0})
  weights={'interest':0.44,'humor':0.23,'praise':0.13,'clarify':0.1,'ack':0.1}
  if dynamic: weights={'candidate_1':0.55,'candidate_2':0.25,'candidate_3':0.15,'candidate_4':0.05}
  reply=dict(type='choice',choice='candidate_1' if dynamic else 'interest',confidence=0.4,probabilities={key:weights.get(key,0.0) for key in body['questions']['reply']['criteria']})
  data=json.dumps({'model':'test-jev','answers':{'intent':choice('interest'),'emotion':choice('hesitant'),'reply':reply,'can_reply':{'type':'noul','noul':0.95}},'usage':{'input_tokens':300,'output_tokens':50}},ensure_ascii=False).encode()
  self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers(); self.wfile.write(data)
 def respond(self,obj):
  data=json.dumps(obj,ensure_ascii=False).encode()
  self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers(); self.wfile.write(data)
 def log_message(self,*args): pass
server=HTTPServer(('127.0.0.1',18765),Handler)
for _ in range(3): server.handle_request()
