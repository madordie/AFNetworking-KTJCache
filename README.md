# AFNetworking-KTJCache
使用AFNetworking 和EGOCache做网络缓存
#部署说明：
    1、如果缓存GET，那么我会告诉你啥都不用做。
    2、如果缓存GET以外的，在你请求前搞一个ktj_cacheAddedKey，千万别重复，否则会读错的。。
    3、还需要做什么？不用了啊。什么都不用了，这就OK了。
    4、注意的是，如果缓存的话你的successBlock会调用两次哟，第一次为缓存，第二次为最新数据。
#使用说明：
    1、这一点很重要！！
        你要看懂这几个参数。
    2、ktj_cacheAddedKey、ktj_cacheData均对当前请求有效，当前请求放飞之后会被重置。
    3、AFHTTPRequestOperationManager的ktj_cacheData为NO时，ktj_cacheAddedKey失效。
    4、ktj_cacheData默认为YES，则只缓存了GET请求。并且忽略ktj_cacheAddedKey参数。
    5、ktj_cacheAddedKey决定是否缓存GET外的请求。如果为空则不缓存，如果有值则缓存。
#注意：
    1、缓存使用EGOCache，如果没有，请pod 或者 拖拽。
    2、根据1可得，这货直接写文件了，没有内存缓存。
