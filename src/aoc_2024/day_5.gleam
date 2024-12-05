import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/set
import gleam/string

// don't need a dict here I guess
type PageOrderDict =
  dict.Dict(Int, set.Set(Int))

fn parse(input: String) -> #(PageOrderDict, PageOrderDict, List(List(Int))) {
  let #(rules_s, updates_s) =
    input
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.split_while(fn(x) { !string.is_empty(x) })

  let #(greater_ord_dict, less_org_dict) = {
    use rule_dict_tuple, rule_s <- list.fold(rules_s, #(dict.new(), dict.new()))
    let #(rule_dict, less_rule_dict) = rule_dict_tuple
    let assert [from, to] = string.split(rule_s, "|")
    let assert Ok(to) = int.parse(to)
    let assert Ok(from) = int.parse(from)
    let out_1 = {
      use o_after_set: option.Option(set.Set(Int)) <- dict.upsert(
        rule_dict,
        from,
      )
      case o_after_set {
        option.Some(after_set) -> set.insert(after_set, to)
        option.None -> set.from_list([to])
      }
    }
    let out_2 = {
      use o_after_set: option.Option(set.Set(Int)) <- dict.upsert(
        less_rule_dict,
        to,
      )
      case o_after_set {
        option.Some(after_set) -> set.insert(after_set, from)
        option.None -> set.from_list([to])
      }
    }
    #(out_1, out_2)
  }
  let up = {
    use update <- list.map(list.drop(updates_s, 1))
    use p_res <- list.map(string.split(update, ","))
    p_res
    |> int.parse
    |> result.unwrap(-1)
  }
  #(greater_ord_dict, less_org_dict, up)
}

pub fn pt_1(input: String) {
  let #(greater_ord_dict, less_org_dict, updates) = parse(input)
  updates
  |> list.filter(fn(update) {
    let sorted_update =
      list.sort(update, order_pages(greater_ord_dict, less_org_dict))
    sorted_update == update
  })
  |> list.map(middle)
  |> int.sum
}

pub fn pt_2(input: String) {
  let #(greater_ord_dict, less_org_dict, updates) = parse(input)
  updates
  |> list.filter_map(fn(update) {
    let sorted_update =
      list.sort(update, order_pages(greater_ord_dict, less_org_dict))
    bool.guard(sorted_update != update, Ok(sorted_update), fn() { Error(Nil) })
  })
  |> list.map(middle)
  |> int.sum
}

fn middle(update) {
  let len = list.length(update)
  {
    use a, index <- list.index_map(update)
    bool.guard(index == { len } / 2, a, fn() { 0 })
  }
  |> int.sum
}

fn order_pages(
  p_ord_g: PageOrderDict,
  p_ord_l: PageOrderDict,
) -> fn(Int, Int) -> order.Order {
  fn(a: Int, b: Int) {
    dict.get(p_ord_g, a)
    |> result.map(fn(greater_set) {
      use <- bool.guard(set.contains(greater_set, b), order.Lt)
      order.Gt
    })
    |> result.lazy_unwrap(fn() {
      io.debug("on no")
      case dict.get(p_ord_l, a) {
        Ok(less_set) -> {
          use <- bool.guard(set.contains(less_set, b), order.Gt)
          order.Lt
        }
        Error(_) -> order.Eq
      }
    })
  }
}
