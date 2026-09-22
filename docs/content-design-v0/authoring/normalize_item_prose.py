"""Bounded Traditional Chinese editorial pass, with a prose-only change audit."""
import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [('weapons_equipment.py','01-weapons-equipment.json'),
         ('supplies_materials_trade.py','02-supplies-materials-trade.json'),
         ('write_relics.py','03-relics-anomalies-unique.json')]
PAIRS = '''这這 个個 为為 发發 后後 头頭 务務 领領 来來 从從 并並 买買 卖賣
须須 设設 确確 认認 给給 气氣 当當 断斷 换換 护護 号號 别別 档檔 类類
关關 场場 暂暫 过過 时時 证證 层層 线線 态態 还還 旧舊 错錯 数數 帐帳
条條 记記 录錄 与與 处處 觉覺 动動 愿願 项項 见見 让讓 专專 业業 点點
针針 书書 费費 电電 测測 压壓 标標 识識 开開 药藥 纸紙 强強 库庫 纳納
万萬 进進 伤傷 导導 图圖 转轉 员員 间間 应應 价價 备備 义義 传傳 网網
则則 该該 绳繩 装裝 齐齊 车車 盖蓋 单單 两兩 无無 对對 实實 会會 冻凍
绝絕 范範 经經 验驗 说說 变變 败敗 货貨 组組 询詢 门門 仅僅 难難 废廢
叶葉 术術 细細 试試 带帶 视視 爱愛 潜潛 杂雜 损損 赔賠 补補 种種 误誤
结結 继繼 续續 编編 织織 约約 笔筆 签簽 许許 职職 岗崗 积積 产產 残殘
净淨 灯燈 户戶 炉爐 梦夢 脏髒 众眾 离離 财財 脱脫 涨漲 迟遲 钱錢 矿礦
庙廟 湿濕 浅淺 队隊 战戰 击擊 抢搶 摆擺 据據 顺順 烧燒 评評 议議 践踐
寿壽 铁鐵 钢鋼 铜銅 钳鉗 锤錘 柜櫃 锁鎖 钥鑰 质質 稳穩 军軍 边邊 尘塵
拦攔 盗盜 虽雖 弃棄 盘盤 余餘 体體 获獲 读讀 听聽 内內 学學 讲講 语語
总總 长長 远遠 凭憑 丢丟 够夠 宽寬 营營 报報 扫掃 载載 资資 劳勞 严嚴
负負 尽盡 轻輕 轮輪 维維 纤纖 缝縫 构構 么麼 着著 钟鐘 弯彎 围圍
敌敵 团團 兴興 裤褲 窃竊 器器 滤濾 乡鄉 乡鄉 协協 绘繪 声聲 却卻
误誤 鉴鑑 断斷 样樣 拥擁 书書 达達 审審 论論 码碼 挤擠 属屬 隐隱
执執 卫衛 随隨 象象 骨骨 胶膠 乐樂 应應 划劃 状狀 够夠 独獨 胜勝
极極 争爭 拣揀 仪儀 检檢 释釋 涉涉 术術 担擔 袋袋 针針 农農 猎獵
庞龐 庆慶 几幾 锈鏽 脚腳 势勢 滥濫 滞滯 拆拆 宽寬 稳穩 执執 挡擋
逻邏 辑輯 称稱 轨軌 岁歲 纪紀 编編 简簡 条條 钩鉤 综綜 缺缺 绑綁
扎紮 账帳 张張 旧舊 额額 艺藝 别別 灵靈 阶階 机機 现現 华華 龙龍 择擇
举舉 虑慮 怀懷 礼禮 观觀 况況 历歷 亲親 陈陳 责責 顶頂 广廣 岭嶺 仓倉
币幣 递遞 励勵 缴繳 恶惡 温溫 厂廠 罗羅 译譯 汉漢 誉譽 紧緊 统統
缠纏 锚錨 铝鋁 环環 丛叢 栈棧 习習'''.split()
TRANS = {ord(p[0]):p[1] for p in PAIRS}

def normalize(text):
    return (text.translate(TRANS).replace('准备','準備').replace('準备','準備')
            .replace('准備','準備').replace('干燥','乾燥').replace('干淨','乾淨')
            .replace('復製','複製').replace('複原','復原'))

def diffs(old,new,path=()):
    assert type(old) is type(new), path
    if isinstance(old,dict):
        assert old.keys()==new.keys(), path
        return sum((diffs(old[k],new[k],path+(k,)) for k in old),[])
    if isinstance(old,list):
        assert len(old)==len(new),path
        return sum((diffs(a,b,path+(i,)) for i,(a,b) in enumerate(zip(old,new))),[])
    return [(path,old,new)] if old!=new else []

if __name__=='__main__':
    audit=[]
    for script,output in FILES:
        target=ROOT/'items'/output
        before=json.loads(target.read_text(encoding='utf-8'))
        author=ROOT/'authoring'/script
        source=author.read_text(encoding='utf-8')
        revised=normalize(source)
        author.write_text(revised,encoding='utf-8')
        runpy.run_path(str(author),run_name='__main__')
        after=json.loads(target.read_text(encoding='utf-8'))
        changes=diffs(before,after)
        # Human prose fields end _zh; stable seed names must remain exact too.
        for path,old,new in changes:
            assert isinstance(old,str) and str(path[-1]).endswith('_zh'),path
            assert path[-1]!='name_zh',path
        audit.append({'file':str(target.relative_to(ROOT)),
                      'changed_prose_fields':len(changes),
                      'changed_record_ids':sorted({before[p[0]]['content_id'] for p,_,_ in changes}),
                      'prose_only':True,'identity_numeric_and_symbolic_fields_unchanged':True})
    print(json.dumps(audit,ensure_ascii=False,indent=2))
